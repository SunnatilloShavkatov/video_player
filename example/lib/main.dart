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
  static const String _karateKidVideoUrl =
      'https://englifypublicvideos.hel1.your-objectstorage.com/movies/elementary_unit_1_the_karate_kid/TRKyawvyNXdOIoLVloLmytyIRSOmgbuUUTqXGMX1.m3u8';
  static const String _karateKidSubtitleUrl =
      'https://d8nrdu71wqkvm.cloudfront.net/1/Y8dVwJMePSsnr7WS7VsrGA04iVcfWnIP.vtt';
  static const String _encryptedVideoUrl =
      'https://d8nrdu71wqkvm.cloudfront.net/transcoded/8pcxxjszsbuhtcdpneytkyqsrbi9ktqampjuquu8trzgzitk0lgbhhb6zrw5kb16/10ffd9c0-3cd8-44a8-896c-d0076e538b9a.m3u8';

  // Encrypted HLS demo: the token is typed in at runtime and kept in memory only.
  final _encryptedUrlController = TextEditingController(text: _encryptedVideoUrl);
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _encryptedUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  /// Returns null (and shows a message) when the URL or token field is empty.
  ({String url, Map<String, String> headers})? _encryptedSource() {
    final url = _encryptedUrlController.text.trim();
    final token = _tokenController.text.trim();
    if (url.isEmpty || token.isEmpty) {
      _showSnackBar('Enter the playlist URL and a fresh token');
      return null;
    }
    return (url: url, headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> _playEncryptedFullscreen() async {
    final source = _encryptedSource();
    if (source == null) {
      return;
    }
    try {
      final result = await VideoPlayer.instance.playVideo(
        playerConfig: PlayerConfiguration.remote(
          videoUrl: source.url,
          title: 'Encrypted Lesson',
          keyRequestHeaders: source.headers,
        ),
      );
      _handlePlaybackResult(result);
    } on ArgumentError catch (e) {
      debugPrint('Invalid video configuration: $e');
      _showSnackBar('Invalid video configuration: ${e.message}');
    }
  }

  Future<void> _openEncryptedEmbedded() async {
    final source = _encryptedSource();
    if (source == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => VideoPlayerPage(url: source.url, keyRequestHeaders: source.headers),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
  }

  void _handlePlaybackResult(PlaybackResult result) {
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
      _handlePlaybackResult(result);
    } on ArgumentError catch (e) {
      debugPrint('Invalid video configuration: $e');
      _showSnackBar('Invalid video configuration: ${e.message}');
    } on Exception catch (e) {
      debugPrint('Unexpected error playing video: $e');
      _showSnackBar('Unexpected error occurred');
    }
  }

  Future<void> _playVideoWithSubtitles({int startPositionSeconds = 50}) async {
    try {
      final result = await VideoPlayer.instance.playVideo(
        playerConfig: PlayerConfiguration.remote(
          videoUrl: _karateKidVideoUrl,
          title: 'The Karate Kid',
          movieShareLink: 'https://uzd.iiii.io/movie/1?type=premier',
          startPositionSeconds: startPositionSeconds,
          subtitles: const [
            SubtitleTrack(id: '227017', label: 'English', lang: 'en', isDefault: true, url: _karateKidSubtitleUrl),
          ],
        ),
      );
      _handlePlaybackResult(result);
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
                      'Launches the native full-screen video player (ExoPlayer on Android, AVPlayer on iOS/macOS) with sidecar WebVTT subtitles, HLS quality selection, playback speed controls, and PiP support.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _playFullscreenVideo,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play Fullscreen Video'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _playVideoWithSubtitles,
                      icon: const Icon(Icons.closed_caption_rounded),
                      label: const Text('Play Karate Kid with Subtitles (Start at 0:50)'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _playVideoWithSubtitles(startPositionSeconds: 0),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Play Karate Kid with Subtitles (Start at 0:00)'),
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
                        await Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (context) => const VideoPlayerPage()));
                      },
                      icon: const Icon(Icons.video_library_rounded),
                      label: const Text('Open Embedded View Demo'),
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
                    Text('Encrypted HLS (AES-128)', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Plays a stream whose key endpoint needs a token. The token goes only to the '
                      'AES key request as "Authorization: Bearer <token>". Do not add ?token= to the URL.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _encryptedUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Playlist URL (hls_path)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tokenController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(labelText: 'Key token (JWT)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _playEncryptedFullscreen,
                      icon: const Icon(Icons.lock_rounded),
                      label: const Text('Play Encrypted Full-Screen'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _openEncryptedEmbedded,
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: const Text('Open Encrypted Embedded View'),
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

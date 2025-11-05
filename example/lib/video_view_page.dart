// ignore_for_file: discarded_futures, unawaited_futures

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/second_page.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerViewController? controller;

  bool isPlay = true;
  bool isMute = false;
  bool isLandscape = false;
  double _duration = 0;
  double _position = 0;
  StreamSubscription<double>? _positionSubscription;

  String _formatTime(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) {
      return '00:00';
    }
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Align(
          child: VideoPlayerView(
            url:
                'https://df5ralxb7y7wh.cloudfront.net/elementary_unit_1_the_karate_kid/TRKyawvyNXdOIoLVloLmytyIRSOmgbuUUTqXGMX1.m3u8',
            onMapViewCreated: _onMapViewCreated,
          ),
        ),
        Positioned(
          child: SafeArea(
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
            ),
          ),
        ),
        Align(
          child: IconButton(
            onPressed: () {
              if (isPlay) {
                controller?.pause();
              } else {
                controller?.play();
              }
              setState(() {
                isPlay = !isPlay;
              });
            },
            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white24)),
            icon: isPlay
                ? const Icon(Icons.pause_rounded, color: Colors.white)
                : const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      isLandscape = !isLandscape;
                    });
                    if (isLandscape) {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                    } else {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.portraitDown,
                      ]);
                    }
                  },
                  icon: const Icon(Icons.screen_rotation),
                  tooltip: 'Rotate screen',
                ),
                IconButton(
                  onPressed: () {
                    if (isMute) {
                      controller?.unmute();
                    } else {
                      controller?.mute();
                    }
                    setState(() {
                      isMute = !isMute;
                    });
                  },
                  icon: isMute ? const Icon(Icons.volume_off) : const Icon(Icons.volume_up),
                ),
              ],
            ),
          ),
        ),
        // Duration and Position display with seek bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seek slider
                  if (_duration > 0)
                    Slider(
                      value: _position.clamp(0.0, _duration),
                      max: _duration,
                      onChanged: (value) {
                        setState(() {
                          _position = value;
                        });
                      },
                      onChangeEnd: (value) {
                        controller?.seekTo(seconds: value);
                      },
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(_position),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatTime(_duration),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // load default assets
  Future<void> _onMapViewCreated(VideoPlayerViewController ctr) async {
    controller = ctr;

    // Listen to duration ready callback (native will call when duration is available)
    ctr.onDurationReady((duration) {
      if (mounted && duration > 0) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position stream
    _positionSubscription?.cancel();
    _positionSubscription = ctr.positionStream.listen((position) {
      if (mounted) {
        if (position.toInt() == 100) {
          controller!.pause();
          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SecondPage()));
        }
        setState(() {
          _position = position;
        });
      }
    });

    ctr.setEventListener((event) {
      if (kDebugMode) {
        print(event);
      }
    });
  }

  @override
  void dispose() {
    // Reset orientation to allow all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    controller?.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }
}

// ignore_for_file: discarded_futures, unawaited_futures

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerViewController? controller;

  bool isPlay = true;
  bool isMute = false;
  double _duration = 0;
  double _position = 0;
  StreamSubscription<double>? _positionSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

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
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).width * 9 / 16,
              child: VideoPlayerView(
                url:
                    'https://df5ralxb7y7wh.cloudfront.net/elementary_unit_1_the_karate_kid/TRKyawvyNXdOIoLVloLmytyIRSOmgbuUUTqXGMX1.m3u8',
                onMapViewCreated: _onMapViewCreated,
              ),
            ),
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
            child: IconButton(
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
          ),
        ),
        // Duration and Position display with seek bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              child: Column(
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
}

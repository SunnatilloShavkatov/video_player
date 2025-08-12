// ignore_for_file: discarded_futures

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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Align(
          child: VideoPlayerView(
            url: 'assets/splash.mp4',
            resizeMode: ResizeMode.fill,
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
            icon: isPlay ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
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
      ],
    ),
  );

  // load default assets
  void _onMapViewCreated(VideoPlayerViewController ctr) {
    controller = ctr;
    ctr.setEventListener((event) {
      if (kDebugMode) {
        print(event);
      }
    });
  }
}

/// 71 205 84 84

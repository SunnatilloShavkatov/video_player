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

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/extensions.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final _videoPlayerPlugin = VideoPlayer();

  Stream<MediaItemDownload> currentProgressDownloadAsStream() =>
      _videoPlayerPlugin.currentProgressDownloadAsStream;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder(
                stream: currentProgressDownloadAsStream(),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  return Text(data == null
                      ? 'Not downloading'
                      : '${data.percent}\n${data.state.toState()}');
                },
              )
            ],
          ),
        ),
      );
}

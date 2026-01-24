import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/video_player_view.dart';

void main() {
  group('VideoPlayerView Lifecycle Safety', () {
    test('ResizeMode enum values are stable', () {
      expect(ResizeMode.fit.name, 'fit');
      expect(ResizeMode.fill.name, 'fill');
      expect(ResizeMode.zoom.name, 'zoom');
    });

    test('PlayerStatus enum values are stable', () {
      expect(PlayerStatus.idle.name, 'idle');
      expect(PlayerStatus.buffering.name, 'buffering');
      expect(PlayerStatus.ready.name, 'ready');
      expect(PlayerStatus.ended.name, 'ended');
      expect(PlayerStatus.playing.name, 'playing');
      expect(PlayerStatus.paused.name, 'paused');
      expect(PlayerStatus.error.name, 'error');
    });

    test('PlayerStatus enum order is stable', () {
      const values = PlayerStatus.values;
      expect(values[0], PlayerStatus.idle);
      expect(values[1], PlayerStatus.buffering);
      expect(values[2], PlayerStatus.ready);
      expect(values[3], PlayerStatus.ended);
      expect(values[4], PlayerStatus.playing);
      expect(values[5], PlayerStatus.paused);
      expect(values[6], PlayerStatus.error);
    });
  });
}

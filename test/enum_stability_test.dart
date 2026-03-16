import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/video_player_view.dart';

void main() {
  group('VideoPlayerView Lifecycle Safety', () {
    test('ResizeMode enum values are stable', () {
      expect(ResizeMode.fit.value, 'fit');
      expect(ResizeMode.fill.value, 'fill');
      expect(ResizeMode.zoom.value, 'zoom');
    });

    test('PlayerStatus enum values are stable', () {
      expect(PlayerStatus.idle.value, 'idle');
      expect(PlayerStatus.buffering.value, 'buffering');
      expect(PlayerStatus.ready.value, 'ready');
      expect(PlayerStatus.ended.value, 'ended');
      expect(PlayerStatus.playing.value, 'playing');
      expect(PlayerStatus.paused.value, 'paused');
      expect(PlayerStatus.error.value, 'error');
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

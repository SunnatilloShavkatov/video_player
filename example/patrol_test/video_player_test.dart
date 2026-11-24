import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
// The failure code type is internal; the plugin's own integration test reads it the same way.
import 'package:video_player/src/native_bridge.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/main.dart';

// End-to-end checks of the example app through the native UI. Run on a device or simulator with
// `patrol test` (not `flutter test`). They stream public HLS samples, so the device needs network.

const _playFullscreen = 'Play Fullscreen Video';
const _openEmbedded = 'Open Embedded View Demo';

/// Time for the native player to open and start the stream before the test acts on it.
const _playerStartup = Duration(seconds: 4);

/// The example shows the session's result as a snack bar; a cancelled or finished session is a clean end.
final _sessionEnded = find.textContaining(RegExp('^Playback (cancelled|finished)'));

final bool _isMobile = Platform.isAndroid || Platform.isIOS;

Future<void> _openFullscreen(PatrolIntegrationTester $) async {
  await $.pumpWidgetAndSettle(const MyApp());
  await $(_playFullscreen).tap();
  await Future<void>.delayed(_playerStartup);
}

void main() {
  patrolTest('home lists the full-screen and embedded demos', ($) async {
    await $.pumpWidgetAndSettle(const MyApp());

    expect($(_playFullscreen), findsOneWidget);
    expect($(_openEmbedded), findsOneWidget);
  });

  patrolTest('full-screen: close() from Dart ends the session', ($) async {
    await _openFullscreen($);

    await VideoPlayer.instance.close().timeout(const Duration(seconds: 10));

    await $(_sessionEnded).waitUntilVisible(timeout: const Duration(seconds: 15));
  });

  patrolTest('full-screen: system back closes the player', skip: !Platform.isAndroid, ($) async {
    await _openFullscreen($);

    await $.platform.android.pressBack();

    await $(_sessionEnded).waitUntilVisible(timeout: const Duration(seconds: 15));
  });

  patrolTest('full-screen: the session survives going to the background', skip: !_isMobile, ($) async {
    await _openFullscreen($);

    await $.platform.mobile.pressHome();
    await Future<void>.delayed(const Duration(seconds: 2));
    await $.platform.mobile.openApp();
    await Future<void>.delayed(const Duration(seconds: 2));

    // Still one session: a second play is rejected until this one is closed.
    final second = await VideoPlayer.instance
        .playVideo(
          playerConfig: PlayerConfiguration.remote(videoUrl: 'https://example.com/v.m3u8', title: 'Second'),
        )
        .timeout(const Duration(seconds: 10));
    expect(((second as PlaybackFailed).error as NativeFailure).code, 'PLAYER_ALREADY_ACTIVE');

    await VideoPlayer.instance.close().timeout(const Duration(seconds: 10));
    await $(_sessionEnded).waitUntilVisible(timeout: const Duration(seconds: 15));
  });

  patrolTest('embedded view mounts the native player and leaves cleanly', ($) async {
    await $.pumpWidgetAndSettle(const MyApp());

    await $(_openEmbedded).scrollTo().tap();
    await $(VideoPlayerView).waitUntilExists(timeout: const Duration(seconds: 10));
    await Future<void>.delayed(_playerStartup);

    await $.tester.pageBack();

    // The home page is visible as soon as the pop transition starts; settle it so the route is disposed.
    await $.pumpAndSettle();
    expect($(_openEmbedded), findsOneWidget);
    expect($(VideoPlayerView), findsNothing);
  });
}

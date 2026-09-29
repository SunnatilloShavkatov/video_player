import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const headers = {'Authorization': 'Bearer secret-token'};
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('embedded player sends keyRequestHeaders in creation params and setUrl', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    Map<Object?, Object?>? creationParams;
    int? viewId;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
      if (call.method == 'create') {
        final args = call.arguments as Map<Object?, Object?>;
        viewId = args['id']! as int;
        final params = args['params']! as Uint8List;
        creationParams =
            const StandardMessageCodec().decodeMessage(ByteData.sublistView(params)) as Map<Object?, Object?>;
      }
      return null;
    });

    VideoPlayerViewController? controller;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: VideoPlayerView(
          url: 'https://example.com/master.m3u8',
          keyRequestHeaders: headers,
          onVideoViewCreated: (c) => controller = c,
        ),
      ),
    );
    await tester.pump();

    expect(creationParams?['keyRequestHeaders'], headers);
    expect(controller, isNotNull);

    MethodCall? setUrlCall;
    messenger.setMockMethodCallHandler(MethodChannel('plugins.video/video_player_view_$viewId'), (call) async {
      setUrlCall = call;
      return null;
    });

    await controller!.setUrl(url: 'https://example.com/other.m3u8', keyRequestHeaders: headers);

    expect(setUrlCall?.method, 'setUrl');
    expect((setUrlCall!.arguments as Map<Object?, Object?>)['keyRequestHeaders'], headers);

    await controller!.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('finished event without arguments reaches the event listener', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    int? viewId;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
      if (call.method == 'create') {
        viewId = (call.arguments as Map<Object?, Object?>)['id']! as int;
      }
      return null;
    });

    VideoPlayerViewController? controller;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: VideoPlayerView(url: 'https://example.com/video.mp4', onVideoViewCreated: (c) => controller = c),
      ),
    );
    await tester.pump();

    Object? received;
    controller!.setEventListener((data) => received = data);

    // Native sends `finished` with null arguments (Android, iOS and macOS).
    const codec = StandardMethodCodec();
    await messenger.handlePlatformMessage(
      'plugins.video/video_player_view_$viewId',
      codec.encodeMethodCall(const MethodCall('finished')),
      (_) {},
    );

    expect(received, isNotNull);

    await controller!.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('controller commands surface errors instead of swallowing them', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    int? viewId;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
      if (call.method == 'create') {
        viewId = (call.arguments as Map<Object?, Object?>)['id']! as int;
      }
      return null;
    });

    VideoPlayerViewController? controller;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: VideoPlayerView(url: 'https://example.com/video.mp4', onVideoViewCreated: (c) => controller = c),
      ),
    );
    await tester.pump();

    final channel = MethodChannel('plugins.video/video_player_view_$viewId');
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) {
      nativeCalls++;
      return Future<ByteData?>.error(PlatformException(code: 'PLAY_ERROR', message: 'boom'));
    });

    await expectLater(controller!.play(), throwsA(isA<PlatformException>()));
    await expectLater(controller!.getDuration(), throwsA(isA<PlatformException>()));

    nativeCalls = 0;
    await expectLater(controller!.setUrl(url: 'http://example.com/video.mp4'), throwsArgumentError);
    await expectLater(controller!.setUrl(url: 'not-a-url'), throwsArgumentError);
    expect(nativeCalls, 0, reason: 'invalid URLs must be rejected before reaching native');

    await controller!.dispose();
    await expectLater(controller!.play(), throwsStateError);
    debugDefaultTargetPlatformOverride = null;
  });
}

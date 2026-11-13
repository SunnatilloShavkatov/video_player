// Regenerates lib/src/bindings/video_player_api.g.dart from the compiled Kotlin facade. Run from the package
// root after a Gradle compile of the example app (`cd example/android && ./gradlew :video_player:compileDebugKotlin`),
// which produces the classes read below: `dart run tool/jnigen.dart`.
import 'dart:io';

import 'package:jnigen/jnigen.dart';

Future<void> main() async {
  final Uri packageRoot = Platform.script.resolve('../');
  final Uri? classes = _newestClasses(packageRoot.resolve('example/build/video_player/'));
  if (classes == null) {
    stderr.writeln('No compiled VideoPlayerApi under example/build; compile the example for Android first.');
    exit(1);
  }
  stdout.writeln('Reading classes from $classes');
  await JniGenerator(
    input: Input(
      classPath: <Uri>[classes],
      classes: <String>[
        'uz.plugin.video_player.VideoPlayerApi',
      ],
      backend: SummarizerBackend.asm,
    ),
    output: Output(
      dart: DartOutput(
        path: packageRoot.resolve('lib/src/bindings/video_player_api.g.dart'),
        structure: OutputStructure.singleFile,
      ),
    ),
  ).generate();
}

// AGP's built-in Kotlin (android.builtInKotlin=true) and the kotlin-android plugin write classes to different
// directories, and a switch between them leaves the other one stale. The freshest facade class wins.
Uri? _newestClasses(Uri pluginBuild) {
  const String facade = 'uz/plugin/video_player/VideoPlayerApi.class';
  Uri? newest;
  DateTime? newestModified;
  for (final String dir in <String>[
    'intermediates/built_in_kotlinc/debug/compileDebugKotlin/classes/',
    'tmp/kotlin-classes/debug/',
  ]) {
    final Uri classes = pluginBuild.resolve(dir);
    final File file = File.fromUri(classes.resolve(facade));
    if (!file.existsSync()) {
      continue;
    }
    final DateTime modified = file.lastModifiedSync();
    if (newestModified == null || modified.isAfter(newestModified)) {
      newest = classes;
      newestModified = modified;
    }
  }
  return newest;
}

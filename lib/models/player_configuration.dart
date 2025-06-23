import 'dart:core';

import 'package:video_player/models/programs_info.dart';
import 'package:video_player/models/season.dart';

import 'package:video_player/models/tv_categories.dart';

export 'programs_info.dart';
export 'season.dart';
export 'tv_categories.dart';
export 'tv_channel.dart';

class PlayerConfiguration {
  const PlayerConfiguration({
    required this.initialResolution,
    required this.resolutions,
    required this.qualityText,
    required this.speedText,
    required this.lastPosition,
    required this.title,
    required this.isSerial,
    required this.episodeButtonText,
    required this.nextButtonText,
    required this.seasons,
    required this.isLive,
    required this.tvProgramsText,
    required this.programsInfoList,
    required this.showController,
    required this.playVideoFromAsset,
    required this.assetPath,
    required this.seasonIndex,
    required this.episodeIndex,
    required this.videoId,
    required this.sessionId,
    required this.authorization,
    required this.autoText,
    required this.fromCache,
    required this.movieShareLink,
    required this.selectChannelIndex,
    this.selectTvCategoryIndex = 0,
    required this.tvCategories,
  });

  final Map<String, String> initialResolution;
  final Map<String, String> resolutions;
  final String qualityText;
  final String speedText;
  final int lastPosition;
  final String title;
  final bool isSerial;
  final String episodeButtonText;
  final String nextButtonText;
  final List<Season> seasons;
  final bool isLive;
  final String tvProgramsText;
  final List<ProgramsInfo> programsInfoList;
  final bool showController;
  final bool playVideoFromAsset;
  final String assetPath;
  final int seasonIndex;
  final int episodeIndex;
  final String videoId;
  final String sessionId;
  final String authorization;
  final String autoText;
  final String movieShareLink;
  final bool fromCache;
  final List<TvCategories> tvCategories;
  final int selectChannelIndex;
  final int selectTvCategoryIndex;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['initialResolution'] = initialResolution;
    map['resolutions'] = resolutions;
    map['qualityText'] = qualityText;
    map['speedText'] = speedText;
    map['lastPosition'] = lastPosition;
    map['title'] = title;
    map['isSerial'] = isSerial;
    map['episodeButtonText'] = episodeButtonText;
    map['nextButtonText'] = nextButtonText;
    map['seasons'] = seasons.map((v) => v.toMap()).toList();
    map['isLive'] = isLive;
    map['tvProgramsText'] = tvProgramsText;
    map['programsInfoList'] = programsInfoList.map((v) => v.toMap()).toList();
    map['showController'] = showController;
    map['playVideoFromAsset'] = playVideoFromAsset;
    map['assetPath'] = assetPath;
    map['seasonIndex'] = seasonIndex;
    map['episodeIndex'] = episodeIndex;
    map['videoId'] = videoId;
    map['sessionId'] = sessionId;
    map['authorization'] = authorization;
    map['autoText'] = autoText;
    map['fromCache'] = fromCache;
    map['movieShareLink'] = movieShareLink;
    map['selectChannelIndex'] = selectChannelIndex;
    map['selectTvCategoryIndex'] = selectTvCategoryIndex;
    map['tvCategories'] = tvCategories.map((v) => v.toMap()).toList();
    return map;
  }

  @override
  String toString() =>
      'PlayerConfiguration{'
      'initialResolution: $initialResolution, '
      'resolutions: $resolutions, '
      'qualityText: $qualityText, '
      'speedText: $speedText, '
      'lastPosition: $lastPosition, '
      'title: $title, '
      'isSerial: $isSerial, '
      'episodeButtonText: $episodeButtonText, '
      'nextButtonText: $nextButtonText, '
      'seasons: $seasons, '
      'isLive: $isLive, '
      'tvProgramsText: $tvProgramsText, '
      'programsInfoList: $programsInfoList, '
      'showController: $showController, '
      'playVideoFromAsset: $playVideoFromAsset, '
      'assetPath: $assetPath, '
      'seasonIndex: $seasonIndex, '
      'episodeIndex: $episodeIndex, '
      'videoId: $videoId, '
      'sessionId: $sessionId, '
      'authorization: $authorization, '
      'autoText: $autoText '
      'fromCache: $fromCache, '
      'movieShareLink: $movieShareLink, '
      'channels: $tvCategories, '
      'selectChannelIndex: $selectChannelIndex'
      '}';
}

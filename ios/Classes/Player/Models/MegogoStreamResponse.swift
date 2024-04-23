// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let megogoStreamResponse = try MegogoStreamResponse(json)

//
// To read values from URLs:
//
//   let task = URLSession.shared.megogoStreamResponseTask(with: url) { megogoStreamResponse, response, error in
//     if let megogoStreamResponse = megogoStreamResponse {
//       ...
//     }
//   }
//   task.resume()

import Foundation

// MARK: - MegogoStreamResponse
struct MegogoStreamResponse: Codable {
    let result: String
    let code: Int
    let data: DataClass
}

// MARK: MegogoStreamResponse convenience initializers and mutators

extension MegogoStreamResponse {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MegogoStreamResponse.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        result: String? = nil,
        code: Int? = nil,
        data: DataClass? = nil
    ) -> MegogoStreamResponse {
        return MegogoStreamResponse(
            result: result ?? self.result,
            code: code ?? self.code,
            data: data ?? self.data
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

//
// To read values from URLs:
//
//   let task = URLSession.shared.dataClassTask(with: url) { dataClass, response, error in
//     if let dataClass = dataClass {
//       ...
//     }
//   }
//   task.resume()

// MARK: - DataClass
struct DataClass: Codable {
    let videoID: Int
    let title: String
    let hierarchyTitles: HierarchyTitles
    let src: String
    let drmType, streamType, contentType: String
    let audioTracks: [AudioTrack]
    let subtitles: [Subtitle]
    let bitrates: [Bitrate]
    let cdnID: Int
    let advertURL: String
    let allowExternalStreaming: Bool
    let startSessionURL: String
    let parentalControlRequired: Bool
    let playStartTime: Int
    let wvls: String
    let watermark: String
    let watermarkClickableEnabled, showBestQualityLink: Bool
    let shareLink: String
    let creditsStart: Int
    let externalSource: Bool
    let previewImages: PreviewImages
    let isAutoplay, isWvdrm, isEmbed, isHierarchy: Bool
    let isLive, isTv, is3D, isUhd: Bool
    let isUhd8K, isHdr, isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case videoID = "video_id"
        case title
        case hierarchyTitles = "hierarchy_titles"
        case src
        case drmType = "drm_type"
        case streamType = "stream_type"
        case contentType = "content_type"
        case audioTracks = "audio_tracks"
        case subtitles, bitrates
        case cdnID = "cdn_id"
        case advertURL = "advert_url"
        case allowExternalStreaming = "allow_external_streaming"
        case startSessionURL = "start_session_url"
        case parentalControlRequired = "parental_control_required"
        case playStartTime = "play_start_time"
        case wvls, watermark
        case watermarkClickableEnabled = "watermark_clickable_enabled"
        case showBestQualityLink = "show_best_quality_link"
        case shareLink = "share_link"
        case creditsStart = "credits_start"
        case externalSource = "external_source"
        case previewImages = "preview_images"
        case isAutoplay = "is_autoplay"
        case isWvdrm = "is_wvdrm"
        case isEmbed = "is_embed"
        case isHierarchy = "is_hierarchy"
        case isLive = "is_live"
        case isTv = "is_tv"
        case is3D = "is_3d"
        case isUhd = "is_uhd"
        case isUhd8K = "is_uhd_8k"
        case isHdr = "is_hdr"
        case isFavorite = "is_favorite"
    }
}

// MARK: DataClass convenience initializers and mutators

extension DataClass {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DataClass.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        videoID: Int? = nil,
        title: String? = nil,
        hierarchyTitles: HierarchyTitles? = nil,
        src: String? = nil,
        drmType: String? = nil,
        streamType: String? = nil,
        contentType: String? = nil,
        audioTracks: [AudioTrack]? = nil,
        subtitles: [Subtitle]? = nil,
        bitrates: [Bitrate]? = nil,
        cdnID: Int? = nil,
        advertURL: String? = nil,
        allowExternalStreaming: Bool? = nil,
        startSessionURL: String? = nil,
        parentalControlRequired: Bool? = nil,
        playStartTime: Int? = nil,
        wvls: String? = nil,
        watermark: String? = nil,
        watermarkClickableEnabled: Bool? = nil,
        showBestQualityLink: Bool? = nil,
        shareLink: String? = nil,
        creditsStart: Int? = nil,
        externalSource: Bool? = nil,
        previewImages: PreviewImages? = nil,
        isAutoplay: Bool? = nil,
        isWvdrm: Bool? = nil,
        isEmbed: Bool? = nil,
        isHierarchy: Bool? = nil,
        isLive: Bool? = nil,
        isTv: Bool? = nil,
        is3D: Bool? = nil,
        isUhd: Bool? = nil,
        isUhd8K: Bool? = nil,
        isHdr: Bool? = nil,
        isFavorite: Bool? = nil
    ) -> DataClass {
        return DataClass(
            videoID: videoID ?? self.videoID,
            title: title ?? self.title,
            hierarchyTitles: hierarchyTitles ?? self.hierarchyTitles,
            src: src ?? self.src,
            drmType: drmType ?? self.drmType,
            streamType: streamType ?? self.streamType,
            contentType: contentType ?? self.contentType,
            audioTracks: audioTracks ?? self.audioTracks,
            subtitles: subtitles ?? self.subtitles,
            bitrates: bitrates ?? self.bitrates,
            cdnID: cdnID ?? self.cdnID,
            advertURL: advertURL ?? self.advertURL,
            allowExternalStreaming: allowExternalStreaming ?? self.allowExternalStreaming,
            startSessionURL: startSessionURL ?? self.startSessionURL,
            parentalControlRequired: parentalControlRequired ?? self.parentalControlRequired,
            playStartTime: playStartTime ?? self.playStartTime,
            wvls: wvls ?? self.wvls,
            watermark: watermark ?? self.watermark,
            watermarkClickableEnabled: watermarkClickableEnabled ?? self.watermarkClickableEnabled,
            showBestQualityLink: showBestQualityLink ?? self.showBestQualityLink,
            shareLink: shareLink ?? self.shareLink,
            creditsStart: creditsStart ?? self.creditsStart,
            externalSource: externalSource ?? self.externalSource,
            previewImages: previewImages ?? self.previewImages,
            isAutoplay: isAutoplay ?? self.isAutoplay,
            isWvdrm: isWvdrm ?? self.isWvdrm,
            isEmbed: isEmbed ?? self.isEmbed,
            isHierarchy: isHierarchy ?? self.isHierarchy,
            isLive: isLive ?? self.isLive,
            isTv: isTv ?? self.isTv,
            is3D: is3D ?? self.is3D,
            isUhd: isUhd ?? self.isUhd,
            isUhd8K: isUhd8K ?? self.isUhd8K,
            isHdr: isHdr ?? self.isHdr,
            isFavorite: isFavorite ?? self.isFavorite
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

//
// To read values from URLs:
//
//   let task = URLSession.shared.audioTrackTask(with: url) { audioTrack, response, error in
//     if let audioTrack = audioTrack {
//       ...
//     }
//   }
//   task.resume()

// MARK: - AudioTrack
struct AudioTrack: Codable {
    let id: Int
    let lang, langTag, langOriginal, displayName: String
    let index: Int
    let requireSubtitles: Bool
    let langISO639_1: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, lang
        case langTag = "lang_tag"
        case langOriginal = "lang_original"
        case displayName = "display_name"
        case index
        case requireSubtitles = "require_subtitles"
        case langISO639_1 = "lang_iso_639_1"
        case isActive = "is_active"
    }
}

// MARK: AudioTrack convenience initializers and mutators

extension AudioTrack {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AudioTrack.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        id: Int? = nil,
        lang: String? = nil,
        langTag: String? = nil,
        langOriginal: String? = nil,
        displayName: String? = nil,
        index: Int? = nil,
        requireSubtitles: Bool? = nil,
        langISO639_1: String? = nil,
        isActive: Bool? = nil
    ) -> AudioTrack {
        return AudioTrack(
            id: id ?? self.id,
            lang: lang ?? self.lang,
            langTag: langTag ?? self.langTag,
            langOriginal: langOriginal ?? self.langOriginal,
            displayName: displayName ?? self.displayName,
            index: index ?? self.index,
            requireSubtitles: requireSubtitles ?? self.requireSubtitles,
            langISO639_1: langISO639_1 ?? self.langISO639_1,
            isActive: isActive ?? self.isActive
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

//
// To read values from URLs:
//
//   let task = URLSession.shared.bitrateTask(with: url) { bitrate, response, error in
//     if let bitrate = bitrate {
//       ...
//     }
//   }
//   task.resume()

// MARK: - Bitrate
struct Bitrate: Codable {
    let bitrate: Int
    let src: String
}

// MARK: Bitrate convenience initializers and mutators

extension Bitrate {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Bitrate.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        bitrate: Int? = nil,
        src: String? = nil
    ) -> Bitrate {
        return Bitrate(
            bitrate: bitrate ?? self.bitrate,
            src: src ?? self.src
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

//
// To read values from URLs:
//
//   let task = URLSession.shared.hierarchyTitlesTask(with: url) { hierarchyTitles, response, error in
//     if let hierarchyTitles = hierarchyTitles {
//       ...
//     }
//   }
//   task.resume()

// MARK: - HierarchyTitles
struct HierarchyTitles: Codable {
    let video: String

    enum CodingKeys: String, CodingKey {
        case video = "VIDEO"
    }
}

// MARK: HierarchyTitles convenience initializers and mutators

extension HierarchyTitles {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(HierarchyTitles.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        video: String? = nil
    ) -> HierarchyTitles {
        return HierarchyTitles(
            video: video ?? self.video
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

//
// To read values from URLs:
//
//   let task = URLSession.shared.previewImagesTask(with: url) { previewImages, response, error in
//     if let previewImages = previewImages {
//       ...
//     }
//   }
//   task.resume()

// MARK: - PreviewImages
struct PreviewImages: Codable {
    let thumbslineXML: String
    let thumbslineList, thumbslineListFullHD, thumbslineListUhd: [ThumbslineList]

    enum CodingKeys: String, CodingKey {
        case thumbslineXML = "thumbsline_xml"
        case thumbslineList = "thumbsline_list"
        case thumbslineListFullHD = "thumbsline_list_full_hd"
        case thumbslineListUhd = "thumbsline_list_uhd"
    }
}

// MARK: PreviewImages convenience initializers and mutators

extension PreviewImages {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PreviewImages.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        thumbslineXML: String? = nil,
        thumbslineList: [ThumbslineList]? = nil,
        thumbslineListFullHD: [ThumbslineList]? = nil,
        thumbslineListUhd: [ThumbslineList]? = nil
    ) -> PreviewImages {
        return PreviewImages(
            thumbslineXML: thumbslineXML ?? self.thumbslineXML,
            thumbslineList: thumbslineList ?? self.thumbslineList,
            thumbslineListFullHD: thumbslineListFullHD ?? self.thumbslineListFullHD,
            thumbslineListUhd: thumbslineListUhd ?? self.thumbslineListUhd
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

//
// To read values from URLs:
//
//   let task = URLSession.shared.thumbslineListTask(with: url) { thumbslineList, response, error in
//     if let thumbslineList = thumbslineList {
//       ...
//     }
//   }
//   task.resume()

// MARK: - ThumbslineList
struct ThumbslineList: Codable {
    let id: Int
    let url: String
}

// MARK: ThumbslineList convenience initializers and mutators

extension ThumbslineList {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ThumbslineList.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        id: Int? = nil,
        url: String? = nil
    ) -> ThumbslineList {
        return ThumbslineList(
            id: id ?? self.id,
            url: url ?? self.url
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

//
// To read values from URLs:
//
//   let task = URLSession.shared.subtitleTask(with: url) { subtitle, response, error in
//     if let subtitle = subtitle {
//       ...
//     }
//   }
//   task.resume()

// MARK: - Subtitle
struct Subtitle: Codable {
    let displayName: String
    let index: Int
    let lang, langISO639_1, langOriginal, langTag: String
    let type: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case index, lang
        case langISO639_1 = "lang_iso_639_1"
        case langOriginal = "lang_original"
        case langTag = "lang_tag"
        case type, url
    }
}

// MARK: Subtitle convenience initializers and mutators

extension Subtitle {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Subtitle.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        displayName: String? = nil,
        index: Int? = nil,
        lang: String? = nil,
        langISO639_1: String? = nil,
        langOriginal: String? = nil,
        langTag: String? = nil,
        type: String? = nil,
        url: String? = nil
    ) -> Subtitle {
        return Subtitle(
            displayName: displayName ?? self.displayName,
            index: index ?? self.index,
            lang: lang ?? self.lang,
            langISO639_1: langISO639_1 ?? self.langISO639_1,
            langOriginal: langOriginal ?? self.langOriginal,
            langTag: langTag ?? self.langTag,
            type: type ?? self.type,
            url: url ?? self.url
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

// MARK: - URLSession response handlers

extension URLSession {
    fileprivate func codableTask<T: Codable>(with url: URL, completionHandler: @escaping (T?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, response, error)
                return
            }
            completionHandler(try? newJSONDecoder().decode(T.self, from: data), response, nil)
        }
    }

    func megogoStreamResponseTask(with url: URL, completionHandler: @escaping (MegogoStreamResponse?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.codableTask(with: url, completionHandler: completionHandler)
    }
}

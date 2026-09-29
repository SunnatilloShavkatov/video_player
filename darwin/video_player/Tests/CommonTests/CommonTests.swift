import AVFoundation
import XCTest

final class SecureURLTests: XCTestCase {
    func testAcceptsHttpsWithHost() {
        XCTAssertTrue(URL(string: "https://example.com/a.m3u8")!.isSecureRemote)
        XCTAssertTrue(URL(string: "HTTPS://example.com/a.m3u8")!.isSecureRemote)
    }

    func testRejectsHttp() {
        XCTAssertFalse(URL(string: "http://example.com/a.m3u8")!.isSecureRemote)
    }

    func testRejectsOtherSchemesAndMissingHost() {
        XCTAssertFalse(URL(string: "file:///tmp/a.mp4")!.isSecureRemote)
        XCTAssertFalse(URL(string: "ftp://example.com/a.mp4")!.isSecureRemote)
        XCTAssertFalse(URL(string: "https://")!.isSecureRemote)
        XCTAssertFalse(URL(string: "assets/a.mp4")!.isSecureRemote)
    }
}

final class SubtitleTrackTests: XCTestCase {
    func testParsesSnakeCaseFlag() {
        let track = SubtitleTrack.fromMap(["id": "1", "label": "English", "lang": "en", "url": "https://x/en.vtt", "is_default": true])
        XCTAssertEqual(track, SubtitleTrack(id: "1", label: "English", lang: "en", isDefault: true, url: "https://x/en.vtt"))
    }

    func testAcceptsNumericIdAndDefaultsFlagToFalse() {
        let track = SubtitleTrack.fromMap(["id": NSNumber(value: 7), "label": "Uzbek", "lang": "uz", "url": "https://x/uz.vtt"])
        XCTAssertEqual(track?.id, "7")
        XCTAssertEqual(track?.isDefault, false)
    }

    func testRejectsMissingRequiredFields() {
        XCTAssertNil(SubtitleTrack.fromMap(["id": "1", "label": "English", "lang": "en"]))
    }
}

final class PlayerConfigurationTests: XCTestCase {
    private func validMap() -> [String: Any] {
        [
            "videoUrl": "https://example.com/a.m3u8", "qualityText": "Quality", "speedText": "Speed",
            "lastPosition": 42, "title": "Title", "playVideoFromAsset": false,
            "autoText": "Auto", "movieShareLink": "https://example.com/share",
        ]
    }

    func testParsesRequiredFieldsWithDefaults() {
        let config = PlayerConfiguration.fromMap(map: validMap())
        XCTAssertEqual(config?.url, "https://example.com/a.m3u8")
        XCTAssertEqual(config?.lastPosition, 42)
        XCTAssertEqual(config?.subtitleOffText, "Off")
        XCTAssertEqual(config?.isScreenshotEnabled, false)
        XCTAssertEqual(config?.keyRequestHeaders, [:])
    }

    func testParsesSubtitlesAndDropsInvalidOnes() {
        var map = validMap()
        map["subtitles"] = [
            ["id": "1", "label": "English", "lang": "en", "url": "https://x/en.vtt"],
            ["id": "2"],
        ]
        XCTAssertEqual(PlayerConfiguration.fromMap(map: map)?.subtitles.count, 1)
    }

    func testRejectsMissingRequiredField() {
        var map = validMap()
        map.removeValue(forKey: "title")
        XCTAssertNil(PlayerConfiguration.fromMap(map: map))
    }
}

final class PlayerUtilsTests: XCTestCase {
    func testTimeStringUnderOneHour() {
        XCTAssertEqual(VGPlayerUtils.getTimeString(from: CMTime(seconds: 75, preferredTimescale: 1)), "01:15")
    }

    func testTimeStringWithHours() {
        XCTAssertEqual(VGPlayerUtils.getTimeString(from: CMTime(seconds: 3725, preferredTimescale: 1)), "1:02:05")
    }

    func testVideoGravityMapping() {
        XCTAssertEqual(videoGravity(s: "fill"), .resizeAspectFill)
        XCTAssertEqual(videoGravity(s: "zoom"), .resize)
        XCTAssertEqual(videoGravity(s: "fit"), .resizeAspect)
        XCTAssertEqual(videoGravity(s: nil), .resizeAspect)
        XCTAssertEqual(videoGravity(s: "unknown"), .resizeAspect)
    }

    func testConvertStringToDictionary() {
        XCTAssertEqual(convertStringToDictionary(text: "{\"a\":1}")?["a"] as? Int, 1)
        XCTAssertNil(convertStringToDictionary(text: "not json"))
    }
}

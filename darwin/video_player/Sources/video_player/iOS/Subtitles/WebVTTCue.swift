#if os(iOS) || os(macOS)
//
//  WebVTTCue.swift
//  video_player
//

import Foundation

public struct WebVTTCue: Equatable {
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let text: String

    public init(startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

public class WebVTTParser {
    public static func parse(vttContent: String) -> [WebVTTCue] {
        var cues: [WebVTTCue] = []
        let lines = vttContent.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // Look for timestamp line: "00:00:55.612 --> 00:00:58.587"
            if line.contains("-->") {
                let parts = line.components(separatedBy: "-->")
                if parts.count >= 2,
                   let start = parseTimestamp(parts[0].trimmingCharacters(in: .whitespaces)),
                   let end = parseTimestamp(parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)[0]) {
                    i += 1
                    var cueTextLines: [String] = []
                    while i < lines.count {
                        let textLine = lines[i].trimmingCharacters(in: .whitespaces)
                        if textLine.isEmpty {
                            break
                        }
                        cueTextLines.append(stripFormattingTags(textLine))
                        i += 1
                    }
                    let cueText = cueTextLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cueText.isEmpty {
                        cues.append(WebVTTCue(startTime: start, endTime: end, text: cueText))
                    }
                }
            }
            i += 1
        }

        return cues.sorted { $0.startTime < $1.startTime }
    }

    public static func findCue(in cues: [WebVTTCue], at time: TimeInterval) -> WebVTTCue? {
        guard !cues.isEmpty else { return nil }

        var low = 0
        var high = cues.count - 1
        var candidateIndex = -1

        while low <= high {
            let mid = (low + high) / 2
            if cues[mid].startTime <= time {
                candidateIndex = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        if candidateIndex >= 0 {
            var idx = candidateIndex
            while idx >= 0 && cues[idx].endTime >= time {
                if cues[idx].startTime <= time && time <= cues[idx].endTime {
                    return cues[idx]
                }
                idx -= 1
            }
        }

        return nil
    }

    private static func parseTimestamp(_ str: String) -> TimeInterval? {
        let parts = str.components(separatedBy: ":")
        var hours: Double = 0
        var minutes: Double = 0
        var seconds: Double = 0

        if parts.count == 3 {
            guard let h = Double(parts[0]),
                  let m = Double(parts[1]),
                  let s = Double(parts[2].replacingOccurrences(of: ",", with: ".")) else {
                return nil
            }
            hours = h
            minutes = m
            seconds = s
        } else if parts.count == 2 {
            guard let m = Double(parts[0]),
                  let s = Double(parts[1].replacingOccurrences(of: ",", with: ".")) else {
                return nil
            }
            minutes = m
            seconds = s
        } else {
            return nil
        }

        return hours * 3600.0 + minutes * 60.0 + seconds
    }

    private static func stripFormattingTags(_ text: String) -> String {
        return text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
#endif
